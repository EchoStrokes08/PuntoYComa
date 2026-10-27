CREATE TYPE report_status AS ENUM ('pending', 'approved', 'rejected', 'expired');
CREATE TABLE community_reports (
  id uuid PRIMARY KEY,
  route_id varchar(128) NOT NULL,
  cell_id varchar(32) NOT NULL,
  category varchar(32) NOT NULL,
  status report_status NOT NULL DEFAULT 'pending',
  anonymous_day_id char(64) NOT NULL,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX community_reports_feed_idx ON community_reports(route_id, cell_id, status, expires_at);
CREATE UNIQUE INDEX community_reports_dedupe_idx ON community_reports(anonymous_day_id, route_id, cell_id, category) WHERE status IN ('pending', 'approved');
