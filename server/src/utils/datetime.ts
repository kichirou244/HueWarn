/** All timestamps sent to the UI use this single format, in Vietnam time. */
const VN_OFFSET_MS = 7 * 60 * 60 * 1000;

const pad = (value: number): string => String(value).padStart(2, '0');

function currentVietnamYear(): number {
  return new Date(Date.now() + VN_OFFSET_MS).getUTCFullYear();
}

function parseTimestamp(value?: string | Date | null): Date {
  if (!value) return new Date();
  if (value instanceof Date) {
    return Number.isNaN(value.getTime()) ? new Date() : value;
  }

  const raw = value.trim();

  // Legacy upstream format: "HH:mm dd/MM(/yyyy)" (already Vietnam local time).
  const legacy = raw.match(
    /^(\d{1,2}):(\d{2})\s+(\d{1,2})\/(\d{1,2})(?:\/(\d{4}))?$/
  );
  if (legacy) {
    const [, hour, minute, day, month, year] = legacy;
    const localAsUtc = new Date(
      Date.UTC(
        year ? Number(year) : currentVietnamYear(),
        Number(month) - 1,
        Number(day),
        Number(hour),
        Number(minute)
      )
    );
    return new Date(localAsUtc.getTime() - VN_OFFSET_MS);
  }

  // ISO strings and HTTP last-modified headers are parsed as UTC.
  const parsed = new Date(raw);
  return Number.isNaN(parsed.getTime()) ? new Date() : parsed;
}

/** Format as "HH:mm dd/MM/yyyy" in Asia/Ho_Chi_Minh (UTC+7, no DST). */
export function formatVietnamTime(value?: string | Date | null): string {
  const utc = parseTimestamp(value);
  const vn = new Date(utc.getTime() + VN_OFFSET_MS);
  return `${pad(vn.getUTCHours())}:${pad(vn.getUTCMinutes())} ${pad(vn.getUTCDate())}/${pad(vn.getUTCMonth() + 1)}/${vn.getUTCFullYear()}`;
}

/** Normalize cached summaries that were stored before the time-format change. */
export function normalizeUpdatedAt<T extends { updatedAt: string }>(value: T): T {
  return { ...value, updatedAt: formatVietnamTime(value.updatedAt) };
}
