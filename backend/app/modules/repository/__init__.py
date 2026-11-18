"""Componente C4 (Nível 2A): Repositório de sessões.

Responsável pela interface de repositório que carrega sessões do SQLite (modo WAL)
e grava alterações em lote (debounce de 1 a 2 s após a última alteração).
"""
