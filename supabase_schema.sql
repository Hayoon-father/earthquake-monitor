-- Supabase 데이터베이스 스키마
-- 지진 정보 테이블 생성

CREATE TABLE earthquakes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id TEXT UNIQUE NOT NULL,
    detected_at TIMESTAMP WITH TIME ZONE NOT NULL,
    region_name TEXT NOT NULL,
    magnitude DECIMAL(3,1) NOT NULL,
    max_intensity INTEGER NOT NULL,
    announced_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX idx_earthquakes_detected_at ON earthquakes(detected_at DESC);
CREATE INDEX idx_earthquakes_magnitude ON earthquakes(magnitude DESC);
CREATE INDEX idx_earthquakes_max_intensity ON earthquakes(max_intensity DESC);
CREATE INDEX idx_earthquakes_created_at ON earthquakes(created_at DESC);

-- 업데이트 시 타임스탬프 자동 갱신 함수
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 트리거 생성
CREATE TRIGGER update_earthquakes_updated_at
    BEFORE UPDATE ON earthquakes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) 설정
ALTER TABLE earthquakes ENABLE ROW LEVEL SECURITY;

-- 모든 사용자가 읽을 수 있도록 설정
CREATE POLICY "Allow read access for all users" ON earthquakes
    FOR SELECT USING (true);

-- 인증된 사용자만 데이터를 삽입할 수 있도록 설정
CREATE POLICY "Allow insert for authenticated users" ON earthquakes
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- 중복 데이터 방지를 위한 upsert 함수
CREATE OR REPLACE FUNCTION upsert_earthquake(
    p_event_id TEXT,
    p_detected_at TIMESTAMP WITH TIME ZONE,
    p_region_name TEXT,
    p_magnitude DECIMAL(3,1),
    p_max_intensity INTEGER,
    p_announced_at TIMESTAMP WITH TIME ZONE
)
RETURNS UUID AS $$
DECLARE
    result_id UUID;
BEGIN
    INSERT INTO earthquakes (event_id, detected_at, region_name, magnitude, max_intensity, announced_at)
    VALUES (p_event_id, p_detected_at, p_region_name, p_magnitude, p_max_intensity, p_announced_at)
    ON CONFLICT (event_id) DO UPDATE SET
        detected_at = EXCLUDED.detected_at,
        region_name = EXCLUDED.region_name,
        magnitude = EXCLUDED.magnitude,
        max_intensity = EXCLUDED.max_intensity,
        announced_at = EXCLUDED.announced_at,
        updated_at = NOW()
    RETURNING id INTO result_id;
    
    RETURN result_id;
END;
$$ LANGUAGE plpgsql;

-- 최근 지진 정보 조회 함수
CREATE OR REPLACE FUNCTION get_recent_earthquakes(limit_count INTEGER DEFAULT 20)
RETURNS TABLE(
    id UUID,
    event_id TEXT,
    detected_at TIMESTAMP WITH TIME ZONE,
    region_name TEXT,
    magnitude DECIMAL(3,1),
    max_intensity INTEGER,
    announced_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT e.id, e.event_id, e.detected_at, e.region_name, e.magnitude, e.max_intensity, e.announced_at, e.created_at
    FROM earthquakes e
    ORDER BY e.detected_at DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- 특정 강도 이상 지진 조회 함수
CREATE OR REPLACE FUNCTION get_earthquakes_by_magnitude(min_magnitude DECIMAL(3,1) DEFAULT 5.0)
RETURNS TABLE(
    id UUID,
    event_id TEXT,
    detected_at TIMESTAMP WITH TIME ZONE,
    region_name TEXT,
    magnitude DECIMAL(3,1),
    max_intensity INTEGER,
    announced_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT e.id, e.event_id, e.detected_at, e.region_name, e.magnitude, e.max_intensity, e.announced_at, e.created_at
    FROM earthquakes e
    WHERE e.magnitude >= min_magnitude
    ORDER BY e.detected_at DESC;
END;
$$ LANGUAGE plpgsql;