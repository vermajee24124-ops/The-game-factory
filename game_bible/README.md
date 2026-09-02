# Game Bible

Each game has a human-readable `Game_Bible.docx` and a machine-readable normalized specification.

The factory must treat the current Game Bible and the existing project state as authoritative inputs. It must never publish secrets or private data from a Game Bible.

For `GME-YYYY-NNNN`, store the source Bible and its normalized spec under the project record, and record a checksum in the manifest.
