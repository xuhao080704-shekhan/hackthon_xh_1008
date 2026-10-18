CREATE TABLE "AvailabilitySubmission" (
  "id" TEXT NOT NULL PRIMARY KEY,
  "participantHash" TEXT NOT NULL,
  "weekStart" TEXT NOT NULL,
  "timezone" TEXT NOT NULL,
  "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" DATETIME NOT NULL
);
CREATE UNIQUE INDEX "AvailabilitySubmission_participantHash_weekStart_key" ON "AvailabilitySubmission"("participantHash", "weekStart");
CREATE INDEX "AvailabilitySubmission_weekStart_idx" ON "AvailabilitySubmission"("weekStart");
CREATE TABLE "AvailabilityInterval" (
  "id" TEXT NOT NULL PRIMARY KEY,
  "submissionId" TEXT NOT NULL,
  "dayOfWeek" INTEGER NOT NULL CHECK ("dayOfWeek" BETWEEN 1 AND 7),
  "start" TEXT NOT NULL,
  "end" TEXT NOT NULL,
  CONSTRAINT "AvailabilityInterval_submissionId_fkey" FOREIGN KEY ("submissionId") REFERENCES "AvailabilitySubmission" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "AvailabilityInterval_submissionId_idx" ON "AvailabilityInterval"("submissionId");
