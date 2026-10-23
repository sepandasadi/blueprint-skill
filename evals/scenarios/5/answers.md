# Scripted user answers — Scenario 5

Each time the agent asks something, give the next unused answer. If the agent asks something not covered, reply "Use your recommended default." If a message contains more than one question, record a failure.

## A0 — mode (should not be asked; if it is, record a failure and answer)
"simple"

## A1 — interpretation
"The first one: the logged-in user downloads their own account data as a CSV file."

## A2 — first requirement question
"It must include every piece of data we hold about the user, including their active sessions so they can see where they are logged in. And the file must never contain anything that could be used to log in as them. Defaults for everything."

## A3 — contradiction (if asked about session tokens vs nothing that logs in)
"List the sessions, but never the token values themselves."

## A4 — Gate 1
"Approved."
