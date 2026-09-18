# Technical Lessons & Architectural Decisions

## Key Decisions

1. **Stremio behaviorHints Extraction**:
   - Parsed `behaviorHints` as both a structured `Map<String, dynamic>` or a raw JSON string to remain compatible with legacy and modern Stremio v3 manifests.
   - Headers extracted from `proxyHeaders` are automatically prioritized over default user agents for CDN stream requests and offline chunk downloads.

2. **Network Stall & Buffer Telemetry**:
   - Buffer cushion is defined as $\text{buffer duration} - \text{current position}$.
   - Telemetry tracks position progress: if `status == buffering` persists for $\ge 15$ seconds without `position` advancing, a non-blocking toast warning is surfaced to offer immediate manual retry or switching to backup streams.

3. **TV Binge Auto-Play Flow**:
   - Next episode countdown triggers at $\le 20$ seconds remaining duration.
   - Stream resolution occurs asynchronously while the 10-second visual countdown ring ticks down, ensuring 0-second gap transitions when auto-playing the next episode.

4. **Offline Vault Integrity & Storage Guard**:
   - Checks available disk space before initiating download tasks. Aborts if available space $< \text{contentLength} + 500\text{MB}$.
