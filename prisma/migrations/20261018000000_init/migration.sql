CREATE TABLE "Archive" (
  "id" TEXT NOT NULL PRIMARY KEY,
  "weekStart" TEXT NOT NULL,
  "groupName" TEXT,
  "data" TEXT NOT NULL,
  "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" DATETIME NOT NULL
);
CREATE INDEX "Archive_weekStart_createdAt_idx" ON "Archive"("weekStart", "createdAt");
CREATE TABLE "UploadRecord" (
  "id" TEXT NOT NULL PRIMARY KEY,
  "batchId" TEXT NOT NULL,
  "originalName" TEXT NOT NULL,
  "type" TEXT NOT NULL,
  "size" INTEGER NOT NULL,
  "status" TEXT NOT NULL DEFAULT 'processing',
  "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX "UploadRecord_batchId_idx" ON "UploadRecord"("batchId");
