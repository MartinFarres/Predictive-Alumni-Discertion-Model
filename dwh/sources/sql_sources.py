from __future__ import annotations

from collections.abc import Iterable, Iterator
from pathlib import Path
from typing import Any

import dlt
import sqlalchemy as sa


def _stream_query(conn_string: str, sql: str, source_name: str) -> Iterator[dict[str, Any]]:
	engine = sa.create_engine(conn_string)
	with engine.connect() as conn:
		result = conn.execution_options(stream_results=True).execute(sa.text(sql))
		for row in result.mappings():
			record = dict(row)
			record["source_db"] = source_name
			yield record


def _stream_query_optional(
	*,
	conn_string: str,
	sql: str,
	source_name: str,
	fallback_sql: str | None = None,
) -> Iterator[dict[str, Any]]:
	try:
		yield from _stream_query(conn_string, sql, source_name)
	except Exception as exc:  # noqa: BLE001
		if fallback_sql is not None:
			try:
				yield from _stream_query(conn_string, fallback_sql, source_name)
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

	def _resource_for_query(name: str, sql: str):
		@dlt.resource(name=name)
		def _resource() -> Iterable[dict[str, Any]]:
			for db in source_dbs:
				yield from _stream_query(db["conn_string"], sql, db["name"])

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

	students = _resource_for_query("students", _read_sql("students.sql"))
	personas = _resource_for_query("personas", _read_sql("personas.sql"))
	academic = _resource_for_query("academic", _read_sql("academic.sql"))
	attendance = _resource_for_query("attendance", _read_sql("attendance.sql"))
	census = _resource_for_query("census", _read_sql("census.sql"))
	dropout = _resource_for_query("dropout", _read_sql("dropout.sql"))
	perdida_regularidades = _resource_for_query("perdida_regularidades", _read_sql("perdida_regularidades.sql"))
	alumnos_hist_calidad = _resource_for_query("alumnos_hist_calidad", _read_sql("alumnos_hist_calidad.sql"))
	elementos = _resource_for_query("elementos", _read_sql("elementos.sql"))
	instancias = _resource_for_query("instancias", _read_sql("instancias.sql"))

	historia_academica = _resource_for_query_optional(
		"historia_academica",
		_read_sql("historia_academica.sql"),
		fallback_sql=_read_sql("historia_academica_fallback.sql"),
	)

	exam_inscriptions = _resource_for_query_optional(
		"exam_inscriptions",
		_read_sql("exam_inscriptions.sql"),
		fallback_sql=None,
	)
	course_inscriptions = _resource_for_query("course_inscriptions", _read_sql("course_inscriptions.sql"))
	reinscripciones = _resource_for_query("reinscripciones", _read_sql("reinscripciones.sql"))

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
