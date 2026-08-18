# Blocking Triage

Use this folder when sessions are waiting, requests are stuck, applications time out, or users report blocking.

Start with:

1. `01-blocking.sql` to find blockers and blocked sessions.
2. `02-active-open-transactions.sql` to find transactions that may be holding locks.

Do not recommend killing sessions until the lead blocker, transaction age, application owner, and business risk are understood.
