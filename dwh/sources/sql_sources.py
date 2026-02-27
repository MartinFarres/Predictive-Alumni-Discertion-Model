from __future__ import annotations

from collections.abc import Iterable, Iterator
import os
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any
import hashlib

import dlt
import sqlalchemy as sa


def _stream_query(
	*,
	conn_string: str,
	sql: str,
	source_name: str,
	params: dict[str, Any] | None = None,
	add_dwh_pk: bool = False,
) -> Iterator[dict[str, Any]]:
	engine = sa.create_engine(conn_string)
	with engine.connect() as conn:
		result = conn.execution_options(stream_results=True).execute(sa.text(sql), params or {})
		for row in result.mappings():
			record = dict(row)
			record["source_db"] = source_name
			if add_dwh_pk:
				# Stable per-row key to enable incremental dedup when cursor resolution is low
				# (e.g., DATE cursors with many records per day).
				pk_parts = [
					source_name,
					str(record.get("persona") or ""),
					str(record.get("alumno") or ""),
					str(record.get("elemento") or ""),
					str(record.get("elemento_revision") or ""),
					str(record.get("instancia") or ""),
					str(record.get("fecha") or ""),
					str(record.get("id_acta") or ""),
					str(record.get("folio") or ""),
					str(record.get("renglon") or ""),
					str(record.get("evaluacion") or ""),
					str(record.get("comision") or ""),
					str(record.get("actividad_codigo") or ""),
					str(record.get("nota") or ""),
					str(record.get("resultado") or ""),
				]
				record["dwh_pk"] = hashlib.sha1("|".join(pk_parts).encode("utf-8")).hexdigest()
			yield record


def _wrap_incremental(sql: str, cursor_column: str) -> str:
	# Wrap query to safely apply incremental WHERE regardless of existing WHERE.
	# NOTE: assumes `cursor_column` is available in the SELECT projection.
	return (
		"SELECT * FROM (\n"
		+ sql.strip().rstrip(";")
		+ f"\n) AS q WHERE q.{cursor_column} IS NOT NULL AND q.{cursor_column} > :cursor ORDER BY q.{cursor_column}"
	)


def _coerce_incremental_value(value: Any, target: Any) -> Any:
	"""Coerce cursor field values to the same *kind* as the incremental state.

	Some Postgres columns come back as DATE in one DB and TIMESTAMPTZ in another.
	dlt requires cursor values to be comparable (same type family).
	"""
	if value is None or target is None:
		return value

	# If target is a date (but not a datetime), coerce datetimes to date.
	if isinstance(target, date) and not isinstance(target, datetime):
		if isinstance(value, datetime):
			return value.date()
		return value

	# If target is a datetime, coerce dates to datetime; also align tzinfo.
	if isinstance(target, datetime):
		if isinstance(value, date) and not isinstance(value, datetime):
			# Use midnight in target timezone (or UTC if none)
			tz = target.tzinfo or timezone.utc
			return datetime(value.year, value.month, value.day, tzinfo=tz)
		if isinstance(value, datetime):
			if target.tzinfo is not None and value.tzinfo is None:
				return value.replace(tzinfo=target.tzinfo)
			return value

	return value


def _incremental_start(default: Any) -> Any:
	# Allows limiting first full backfill for huge tables without changing code.
	# Example: DWH_INCREMENTAL_START_DATE=2020-01-01
	v = os.getenv("DWH_INCREMENTAL_START_DATE", "").strip()
	if not v:
		return default

	# Coerce env value to the same kind of type as the default.
	try:
		if isinstance(default, datetime):
			# Accept YYYY-MM-DD (midnight) or full ISO datetime.
			parsed = datetime.fromisoformat(v) if "T" in v else datetime.fromisoformat(f"{v}T00:00:00")
			# If the default is tz-aware and the env value isn't, inherit tzinfo.
			if default.tzinfo is not None and parsed.tzinfo is None:
				parsed = parsed.replace(tzinfo=default.tzinfo)
			return parsed
		if isinstance(default, date):
			return date.fromisoformat(v)
		if isinstance(default, int):
			# Allow using date-based start limits for integer composite cursors.
			# We interpret the env as YYYY-MM-DD (midnight) and convert to epoch seconds.
			d = date.fromisoformat(v)
			epoch = int(datetime(d.year, d.month, d.day).timestamp())
			# Must match the multiplier used in SQL (see historia_academica*.sql)
			return epoch * 100000000
	except Exception:  # noqa: BLE001
		return default

	return default


def _stream_query_optional(
	*,
	conn_string: str,
	sql: str,
	source_name: str,
	fallback_sql: str | None = None,
	add_dwh_pk: bool = False,
) -> Iterator[dict[str, Any]]:
	try:
		yield from _stream_query(
			conn_string=conn_string,
			sql=sql,
			source_name=source_name,
			add_dwh_pk=add_dwh_pk,
		)
	except Exception as exc:  # noqa: BLE001
		if fallback_sql is not None:
			try:
				yield from _stream_query(
					conn_string=conn_string,
					sql=fallback_sql,
					source_name=source_name,
					add_dwh_pk=add_dwh_pk,
				)
				return
			except Exception as exc2:  # noqa: BLE001
				print(f"[Bronze][E] Query failed for {source_name} (fallback also failed): {exc2}")
				return
		print(f"[Bronze][E] Optional query skipped for {source_name}: {exc}")


@dlt.source
def guarani_multi_source(source_dbs: list[dict[str, str]]):
	"""dlt source that extracts multiple datasets from multiple Guarani DBs.

	Each resource concatenates rows from all source DBs and adds `source_db`.
	"""

	base_dir = Path(__file__).resolve().parents[1]
	sql_dir = base_dir / "sql" / "bronze"

	def _read_sql(filename: str) -> str:
		path = sql_dir / filename
		return path.read_text(encoding="utf-8")

	def _resource_for_query(name: str, sql: str, *, write_disposition: str = "replace"):
		@dlt.resource(name=name, write_disposition=write_disposition)
		def _resource() -> Iterable[dict[str, Any]]:
			for db in source_dbs:
				yield from _stream_query(conn_string=db["conn_string"], sql=sql, source_name=db["name"])

		return _resource

	def _resource_for_query_optional(name: str, sql: str, *, fallback_sql: str | None = None):
		@dlt.resource(name=name)
		def _resource() -> Iterable[dict[str, Any]]:
			for db in source_dbs:
				yield from _stream_query_optional(
					conn_string=db["conn_string"],
					sql=sql,
					source_name=db["name"],
					fallback_sql=fallback_sql,
				)

		return _resource

	def _resource_for_query_incremental(
		name: str,
		sql: str,
		*,
		cursor_column: str,
		initial_value: Any,
		write_disposition: str = "append",
		primary_key: str | list[str] | None = None,
		columns: dict[str, Any] | None = None,
	):
		@dlt.resource(
			name=name,
			write_disposition=write_disposition,
			primary_key=primary_key,
			columns=columns,
		)
		def _resource(
			cursor=dlt.sources.incremental(cursor_column, initial_value=_incremental_start(initial_value))
		) -> Iterable[dict[str, Any]]:
			wrapped = _wrap_incremental(sql, cursor_column)
			add_dwh_pk = primary_key == "dwh_pk" or (columns is not None and "dwh_pk" in columns)
			for db in source_dbs:
				for record in _stream_query(
					conn_string=db["conn_string"],
					sql=wrapped,
					source_name=db["name"],
					params={"cursor": cursor.last_value},
					add_dwh_pk=add_dwh_pk,
				):
					record[cursor_column] = _coerce_incremental_value(record.get(cursor_column), cursor.last_value)
					yield record

		return _resource

	def _resource_for_query_incremental_optional(
		name: str,
		sql: str,
		*,
		cursor_column: str,
		initial_value: Any,
		fallback_sql: str | None = None,
		write_disposition: str = "append",
		primary_key: str | list[str] | None = None,
		columns: dict[str, Any] | None = None,
	):
		@dlt.resource(
			name=name,
			write_disposition=write_disposition,
			primary_key=primary_key,
			columns=columns,
		)
		def _resource(
			cursor=dlt.sources.incremental(cursor_column, initial_value=_incremental_start(initial_value))
		) -> Iterable[dict[str, Any]]:
			wrapped = _wrap_incremental(sql, cursor_column)
			wrapped_fallback = _wrap_incremental(fallback_sql, cursor_column) if fallback_sql else None
			add_dwh_pk = primary_key == "dwh_pk" or (columns is not None and "dwh_pk" in columns)

			for db in source_dbs:
				try:
					for record in _stream_query(
						conn_string=db["conn_string"],
						sql=wrapped,
						source_name=db["name"],
						params={"cursor": cursor.last_value},
							add_dwh_pk=add_dwh_pk,
					):
						record[cursor_column] = _coerce_incremental_value(record.get(cursor_column), cursor.last_value)
						yield record
				except Exception as exc:  # noqa: BLE001
					if wrapped_fallback:
						print(f"[Bronze][WARN] {name} failed for {db['name']}; trying fallback ({exc})")
						try:
							for record in _stream_query(
								conn_string=db["conn_string"],
								sql=wrapped_fallback,
								source_name=db["name"],
								params={"cursor": cursor.last_value},
								add_dwh_pk=add_dwh_pk,
							):
								record[cursor_column] = _coerce_incremental_value(record.get(cursor_column), cursor.last_value)
								yield record
						except Exception as exc2:  # noqa: BLE001
							print(f"[Bronze][E] {name} fallback also failed for {db['name']}: {exc2}")
					else:
						print(f"[Bronze][WARN] Optional resource {name} skipped for {db['name']}: {exc}")

		return _resource

	# Small/static dimensions: full refresh.
	students = _resource_for_query("students", _read_sql("students.sql"), write_disposition="replace")
	personas = _resource_for_query("personas", _read_sql("personas.sql"), write_disposition="replace")
	elementos = _resource_for_query("elementos", _read_sql("elementos.sql"), write_disposition="replace")
	instancias = _resource_for_query("instancias", _read_sql("instancias.sql"), write_disposition="replace")

	# Large/event/history tables: incremental by default to avoid full reloads.
	academic = _resource_for_query_incremental(
		"academic",
		_read_sql("academic.sql"),
		cursor_column="fecha_nota",
		initial_value=date(1900, 1, 1),
	)
	census = _resource_for_query_incremental(
		"census",
		_read_sql("census.sql"),
		cursor_column="fecha",
		initial_value=date(1900, 1, 1),
	)
	dropout = _resource_for_query_incremental(
		"dropout",
		_read_sql("dropout.sql"),
		cursor_column="fecha_dropout",
		initial_value=date(1900, 1, 1),
	)
	perdida_regularidades = _resource_for_query_incremental(
		"perdida_regularidades",
		_read_sql("perdida_regularidades.sql"),
		cursor_column="fecha",
		initial_value=date(1900, 1, 1),
	)
	alumnos_hist_calidad = _resource_for_query_incremental(
		"alumnos_hist_calidad",
		_read_sql("alumnos_hist_calidad.sql"),
		cursor_column="fecha",
		# This cursor comes back as a tz-aware timestamp in some DBs
		initial_value=datetime(1900, 1, 1, tzinfo=timezone.utc),
	)

	# Attendance has no timestamp in our query -> full refresh.
	attendance = _resource_for_query("attendance", _read_sql("attendance.sql"), write_disposition="replace")

	historia_academica = _resource_for_query_incremental_optional(
		"historia_academica",
		_read_sql("historia_academica.sql"),
		cursor_column="fecha",
		initial_value=date(1900, 1, 1),
		fallback_sql=_read_sql("historia_academica_fallback.sql"),
		primary_key="dwh_pk",
		columns={
			"dwh_pk": {"data_type": "text"},
			"nro_resolucion": {"data_type": "text"},
			"nro_resolucion_descripcion": {"data_type": "text"},
			"reconocimiento_nro_tramite": {"data_type": "text"},
			"reconocimiento_nro_tramite_original": {"data_type": "text"},
			"reconocimiento_tipo_tramite": {"data_type": "text"},
			"reconocimiento_act": {"data_type": "text"},
			"fecha_vigencia": {"data_type": "date"},
			"nua": {"data_type": "text"},
		},
	)

	exam_inscriptions = _resource_for_query_incremental_optional(
		"exam_inscriptions",
		_read_sql("exam_inscriptions.sql"),
		cursor_column="fecha_mesa_examen",
		# DATE vs TIMESTAMPTZ varies by source; we coerce yielded values to match
		initial_value=date(1900, 1, 1),
		fallback_sql=None,
	)
	course_inscriptions = _resource_for_query_incremental(
		"course_inscriptions",
		_read_sql("course_inscriptions.sql"),
		cursor_column="fecha_inscripcion",
		# DATE vs TIMESTAMPTZ varies by source; we coerce yielded values to match
		initial_value=datetime(1900, 1, 1, tzinfo=timezone.utc),
	)
	reinscripciones = _resource_for_query_incremental(
		"reinscripciones",
		_read_sql("reinscripciones.sql"),
		cursor_column="fecha_reinscripcion",
		# DATE vs TIMESTAMPTZ varies by source; we coerce yielded values to match
		initial_value=datetime(1900, 1, 1, tzinfo=timezone.utc),
	)

	return (
		students,
		personas,
		academic,
		attendance,
		census,
		dropout,
		perdida_regularidades,
		alumnos_hist_calidad,
		elementos,
		instancias,
		historia_academica,
		exam_inscriptions,
		course_inscriptions,
		reinscripciones,
	)
