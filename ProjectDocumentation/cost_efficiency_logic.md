# Cost Efficiency Logic

## 1. Cosmos DB (Hot Tier)
- Store **only the last 90 days** of billing records.
- Cosmos DB is the expensive part of the architecture because you pay for **RU/s** + **storage**.
- Setting `default_ttl = 7776000` (90 days) ensures old records are **auto-purged**.
- The `archive_records.sh` script moves data at **~85 days** to Blob Storage so you don’t lose it before TTL deletion.

### Why 85 Days and Not 90?
- TTL deletion happens automatically at 90 days, so we create a **5-day safety buffer**.
- Archiving at ~85 days ensures:
  - No data loss due to clock drift or slow queries.
  - Data is safely in Blob before Cosmos DB purges it.
- This buffer is a deliberate **risk mitigation step**, not a limit of the system.

---

## 2. Blob Storage (Cool → Archive Tier)
- **Cool Tier**: Immediately move archived data to Cool tier (low storage cost, higher read cost).
- **Archive Tier**: After 30 days in Cool tier, automatically move to Archive tier (very low storage cost, slower retrieval).

### Storage Cost Example (East US, 2025 rates, 1 TB data)
| Tier         | Cost/Month/TB | Retrieval Cost     | Retrieval Time  |
|--------------|---------------|--------------------|-----------------|
| Cool         | ~$10          | Moderate           | Instant         |
| Archive      | ~$1           | High (per GB)      | Hours           |

- Archive tier is **~10x cheaper** than Cool tier for storage.
- Retrieval from archive tier is rare and handled by the rehydrate function.

---

## 3. Why It’s Cost-Effective
1. **Cosmos DB Hot Data**: Only 3 months stored → smaller RU/s and lower storage cost.
2. **Blob Cold Data**: Mostly in archive tier → cheapest Azure storage option.
3. **No compute/RU/s** cost for cold data, only storage cost.

---

## 4. Projected Data Flow
| Age of Record | Location         | Tier     | Notes |
|---------------|-----------------|----------|-------|
| 0–85 days     | Cosmos DB        | N/A      | Full performance, low latency |
| 85–115 days   | Blob Storage     | Cool     | Recently archived, cheaper than hot |
| 115+ days     | Blob Storage     | Archive  | Very low cost, retrieval takes hours |

---

## 5. Recommendation
For maximum cost savings:
- Keep Cool tier duration short (e.g., 30 days) before moving to Archive.
- Use Archive tier for long-term retention with minimal access.
