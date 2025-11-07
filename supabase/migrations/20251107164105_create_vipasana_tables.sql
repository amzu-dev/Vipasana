-- ============================================================================
-- Vipasana App Database Schema (Device-Based Authentication)
-- ============================================================================
-- Description: Tables and functions for Vipasana meditation app
-- Authentication: Device-based anonymized ID (no Supabase Auth)
-- Prefix: vipasana_ (to separate from other apps in ZenWalk database)
-- Version: 1.0
-- Date: November 2025
-- ============================================================================

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TABLE: vipasana_users
-- ============================================================================
-- Description: User profiles identified by anonymized device ID
-- ============================================================================

CREATE TABLE IF NOT EXISTS vipasana_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id TEXT UNIQUE NOT NULL, -- Anonymized device identifier
    display_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Privacy & Compliance
    health_agreement_accepted BOOLEAN DEFAULT FALSE,
    health_agreement_accepted_at TIMESTAMPTZ,
    health_agreement_version TEXT,
    privacy_policy_accepted BOOLEAN DEFAULT FALSE,
    privacy_policy_version TEXT,
    privacy_policy_accepted_at TIMESTAMPTZ,
    terms_accepted BOOLEAN DEFAULT FALSE,
    terms_version TEXT,
    terms_accepted_at TIMESTAMPTZ,

    -- Preferences (JSON)
    preferences JSONB DEFAULT '{}'::jsonb,

    -- Subscription (tracked from App Store)
    subscription_status TEXT CHECK (subscription_status IN ('free', 'trial', 'monthly', 'yearly', 'lifetime')) DEFAULT 'free',
    subscription_tier TEXT CHECK (subscription_tier IN ('free', 'premium')) DEFAULT 'free',
    subscription_start_date TIMESTAMPTZ,
    subscription_end_date TIMESTAMPTZ,
    trial_start_date TIMESTAMPTZ,
    trial_end_date TIMESTAMPTZ,

    -- Apple IAP
    original_transaction_id TEXT,
    latest_receipt TEXT,
    
    -- Last seen for cleanup
    last_seen_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for vipasana_users
CREATE INDEX IF NOT EXISTS idx_vipasana_users_device_id ON vipasana_users(device_id);
CREATE INDEX IF NOT EXISTS idx_vipasana_users_subscription_status ON vipasana_users(subscription_status);
CREATE INDEX IF NOT EXISTS idx_vipasana_users_created_at ON vipasana_users(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_vipasana_users_last_seen ON vipasana_users(last_seen_at DESC);

-- Trigger to update updated_at
CREATE TRIGGER update_vipasana_users_updated_at
    BEFORE UPDATE ON vipasana_users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TABLE: vipasana_meditation_sessions
-- ============================================================================
-- Description: Meditation session records for tracking and statistics
-- ============================================================================

CREATE TABLE IF NOT EXISTS vipasana_meditation_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES vipasana_users(id) ON DELETE CASCADE,

    -- Session data
    start_time TIMESTAMPTZ NOT NULL,
    duration_seconds INTEGER NOT NULL CHECK (duration_seconds > 0),
    session_type TEXT NOT NULL,
    is_guided BOOLEAN DEFAULT FALSE,
    completed BOOLEAN DEFAULT TRUE,

    -- Metadata for sync and deduplication
    device_id TEXT NOT NULL,
    local_id TEXT, -- Original SwiftData ID for deduplication
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for vipasana_meditation_sessions
CREATE INDEX IF NOT EXISTS idx_vipasana_sessions_user_id ON vipasana_meditation_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_vipasana_sessions_start_time ON vipasana_meditation_sessions(user_id, start_time DESC);
CREATE INDEX IF NOT EXISTS idx_vipasana_sessions_device_local ON vipasana_meditation_sessions(user_id, device_id, local_id);
CREATE INDEX IF NOT EXISTS idx_vipasana_sessions_completed ON vipasana_meditation_sessions(user_id, completed) WHERE completed = true;

-- Unique constraint to prevent duplicate sessions from same device
CREATE UNIQUE INDEX IF NOT EXISTS idx_vipasana_sessions_unique
    ON vipasana_meditation_sessions(user_id, device_id, local_id)
    WHERE local_id IS NOT NULL;

-- Trigger to update updated_at
CREATE TRIGGER update_vipasana_sessions_updated_at
    BEFORE UPDATE ON vipasana_meditation_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TABLE: vipasana_user_settings
-- ============================================================================
-- Description: User preferences and app settings
-- ============================================================================

CREATE TABLE IF NOT EXISTS vipasana_user_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES vipasana_users(id) ON DELETE CASCADE,

    -- Breathing settings
    breathing_inhale_duration NUMERIC(4,1) DEFAULT 6.0 CHECK (breathing_inhale_duration BETWEEN 2.0 AND 10.0),
    breathing_exhale_duration NUMERIC(4,1) DEFAULT 6.0 CHECK (breathing_exhale_duration BETWEEN 2.0 AND 10.0),
    interval_bells_enabled BOOLEAN DEFAULT TRUE,

    -- Appearance settings
    background_color TEXT,
    circle_color TEXT,

    -- Sync metadata
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    device_id TEXT NOT NULL,

    CONSTRAINT unique_user_settings UNIQUE(user_id)
);

-- Index for vipasana_user_settings
CREATE INDEX IF NOT EXISTS idx_vipasana_settings_user ON vipasana_user_settings(user_id);

-- Trigger to update updated_at
CREATE TRIGGER update_vipasana_settings_updated_at
    BEFORE UPDATE ON vipasana_user_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TABLE: vipasana_subscription_history
-- ============================================================================
-- Description: Audit trail for subscription events
-- ============================================================================

CREATE TABLE IF NOT EXISTS vipasana_subscription_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES vipasana_users(id) ON DELETE CASCADE,

    -- Event details
    event_type TEXT NOT NULL CHECK (event_type IN (
        'trial_started',
        'trial_ended',
        'trial_converted',
        'subscribed',
        'renewed',
        'cancelled',
        'expired',
        'refunded',
        'billing_issue'
    )),
    subscription_tier TEXT CHECK (subscription_tier IN ('monthly', 'yearly', 'lifetime')),

    -- Apple IAP details
    transaction_id TEXT,
    original_transaction_id TEXT,
    product_id TEXT,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Indexes for vipasana_subscription_history
CREATE INDEX IF NOT EXISTS idx_vipasana_subscription_history_user ON vipasana_subscription_history(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_vipasana_subscription_history_event ON vipasana_subscription_history(event_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_vipasana_subscription_history_transaction ON vipasana_subscription_history(original_transaction_id);

-- ============================================================================
-- TABLE: vipasana_agreement_logs
-- ============================================================================
-- Description: Legal compliance tracking for user agreements
-- ============================================================================

CREATE TABLE IF NOT EXISTS vipasana_agreement_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES vipasana_users(id) ON DELETE CASCADE,

    -- Agreement details
    agreement_type TEXT NOT NULL CHECK (agreement_type IN ('health_safety', 'privacy_policy', 'terms_of_service')),
    agreement_version TEXT NOT NULL,
    accepted BOOLEAN NOT NULL,
    accepted_at TIMESTAMPTZ DEFAULT NOW(),

    -- Compliance metadata
    device_info JSONB DEFAULT '{}'::jsonb
);

-- Indexes for vipasana_agreement_logs
CREATE INDEX IF NOT EXISTS idx_vipasana_agreement_logs_user ON vipasana_agreement_logs(user_id, agreement_type, accepted_at DESC);
CREATE INDEX IF NOT EXISTS idx_vipasana_agreement_logs_type ON vipasana_agreement_logs(agreement_type, agreement_version);

-- ============================================================================
-- TABLE: vipasana_api_keys (for device authentication)
-- ============================================================================
-- Description: API keys for device-based authentication
-- ============================================================================

CREATE TABLE IF NOT EXISTS vipasana_api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    api_key TEXT UNIQUE NOT NULL,
    device_id TEXT NOT NULL,
    user_id UUID REFERENCES vipasana_users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE
);

-- Indexes for vipasana_api_keys
CREATE INDEX IF NOT EXISTS idx_vipasana_api_keys_key ON vipasana_api_keys(api_key) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_vipasana_api_keys_device ON vipasana_api_keys(device_id);
CREATE INDEX IF NOT EXISTS idx_vipasana_api_keys_user ON vipasana_api_keys(user_id);

-- ============================================================================
-- DATABASE FUNCTIONS
-- ============================================================================

-- ============================================================================
-- FUNCTION: vipasana_authenticate_device
-- ============================================================================
-- Description: Authenticate device and return/create user
-- Parameters: p_device_id TEXT
-- Returns: user_id UUID, api_key TEXT
-- ============================================================================

CREATE OR REPLACE FUNCTION vipasana_authenticate_device(p_device_id TEXT)
RETURNS TABLE (
    user_id UUID,
    api_key TEXT,
    is_new_user BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_api_key TEXT;
    v_is_new BOOLEAN := FALSE;
BEGIN
    -- Check if user exists
    SELECT id INTO v_user_id
    FROM vipasana_users
    WHERE device_id = p_device_id;

    -- Create user if doesn't exist
    IF v_user_id IS NULL THEN
        INSERT INTO vipasana_users (device_id)
        VALUES (p_device_id)
        RETURNING id INTO v_user_id;
        
        v_is_new := TRUE;
    ELSE
        -- Update last seen
        UPDATE vipasana_users
        SET last_seen_at = NOW()
        WHERE id = v_user_id;
    END IF;

    -- Generate or get existing API key
    SELECT api_key INTO v_api_key
    FROM vipasana_api_keys
    WHERE device_id = p_device_id AND is_active = TRUE
    LIMIT 1;

    IF v_api_key IS NULL THEN
        -- Generate new API key
        v_api_key := encode(gen_random_bytes(32), 'hex');
        
        INSERT INTO vipasana_api_keys (api_key, device_id, user_id)
        VALUES (v_api_key, p_device_id, v_user_id);
    ELSE
        -- Update last used
        UPDATE vipasana_api_keys
        SET last_used_at = NOW()
        WHERE api_key = v_api_key;
    END IF;

    RETURN QUERY SELECT v_user_id, v_api_key, v_is_new;
END;
$$;

-- ============================================================================
-- FUNCTION: vipasana_get_user_by_api_key
-- ============================================================================
-- Description: Get user ID from API key
-- Parameters: p_api_key TEXT
-- Returns: user_id UUID
-- ============================================================================

CREATE OR REPLACE FUNCTION vipasana_get_user_by_api_key(p_api_key TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    SELECT user_id INTO v_user_id
    FROM vipasana_api_keys
    WHERE api_key = p_api_key AND is_active = TRUE;

    -- Update last used
    IF v_user_id IS NOT NULL THEN
        UPDATE vipasana_api_keys
        SET last_used_at = NOW()
        WHERE api_key = p_api_key;
        
        UPDATE vipasana_users
        SET last_seen_at = NOW()
        WHERE id = v_user_id;
    END IF;

    RETURN v_user_id;
END;
$$;

-- ============================================================================
-- FUNCTION: vipasana_get_user_stats
-- ============================================================================
-- Description: Get comprehensive statistics for a user
-- Parameters: p_user_id UUID
-- Returns: Aggregated session statistics
-- ============================================================================

CREATE OR REPLACE FUNCTION vipasana_get_user_stats(p_user_id UUID)
RETURNS TABLE (
    total_sessions BIGINT,
    total_minutes BIGINT,
    completed_sessions BIGINT,
    avg_duration_minutes NUMERIC,
    first_session_date TIMESTAMPTZ,
    last_session_date TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*)::BIGINT as total_sessions,
        COALESCE(SUM(duration_seconds / 60), 0)::BIGINT as total_minutes,
        COUNT(*) FILTER (WHERE completed = true)::BIGINT as completed_sessions,
        COALESCE(AVG(duration_seconds / 60.0), 0)::NUMERIC(10,2) as avg_duration_minutes,
        MIN(start_time) as first_session_date,
        MAX(start_time) as last_session_date
    FROM vipasana_meditation_sessions
    WHERE user_id = p_user_id;
END;
$$;

-- ============================================================================
-- FUNCTION: vipasana_calculate_streak
-- ============================================================================
-- Description: Calculate current meditation streak in days
-- Parameters: p_user_id UUID
-- Returns: Number of consecutive days with meditation
-- ============================================================================

CREATE OR REPLACE FUNCTION vipasana_calculate_streak(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_streak INTEGER := 0;
    v_current_date DATE := CURRENT_DATE;
    v_has_session BOOLEAN;
BEGIN
    -- Calculate streak: consecutive days with at least one completed session
    LOOP
        SELECT EXISTS(
            SELECT 1
            FROM vipasana_meditation_sessions
            WHERE user_id = p_user_id
              AND DATE(start_time AT TIME ZONE 'UTC') = v_current_date
              AND completed = true
        ) INTO v_has_session;

        EXIT WHEN NOT v_has_session;

        v_streak := v_streak + 1;
        v_current_date := v_current_date - INTERVAL '1 day';

        -- Safety limit to prevent infinite loops
        EXIT WHEN v_streak > 365;
    END LOOP;

    RETURN v_streak;
END;
$$;

-- ============================================================================
-- FUNCTION: vipasana_check_subscription_active
-- ============================================================================
-- Description: Check if user has active premium subscription
-- Parameters: p_user_id UUID
-- Returns: Boolean indicating active subscription status
-- ============================================================================

CREATE OR REPLACE FUNCTION vipasana_check_subscription_active(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_status TEXT;
    v_end_date TIMESTAMPTZ;
BEGIN
    SELECT subscription_status, subscription_end_date
    INTO v_status, v_end_date
    FROM vipasana_users
    WHERE id = p_user_id;

    -- Check if subscription is active
    IF v_status IN ('trial', 'monthly', 'yearly', 'lifetime') THEN
        -- Lifetime is always active
        IF v_status = 'lifetime' THEN
            RETURN TRUE;
        END IF;

        -- For others, check end date
        IF v_end_date IS NULL OR v_end_date > NOW() THEN
            RETURN TRUE;
        END IF;
    END IF;

    RETURN FALSE;
END;
$$;

-- ============================================================================
-- FUNCTION: vipasana_get_sessions_by_date_range
-- ============================================================================
-- Description: Get sessions within a date range for a user
-- Parameters: p_user_id UUID, p_start_date DATE, p_end_date DATE
-- Returns: Sessions within the date range
-- ============================================================================

CREATE OR REPLACE FUNCTION vipasana_get_sessions_by_date_range(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    session_date DATE,
    session_count BIGINT,
    total_minutes BIGINT,
    guided_count BIGINT,
    unguided_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        DATE(start_time AT TIME ZONE 'UTC') as session_date,
        COUNT(*)::BIGINT as session_count,
        SUM(duration_seconds / 60)::BIGINT as total_minutes,
        COUNT(*) FILTER (WHERE is_guided = true)::BIGINT as guided_count,
        COUNT(*) FILTER (WHERE is_guided = false)::BIGINT as unguided_count
    FROM vipasana_meditation_sessions
    WHERE user_id = p_user_id
      AND completed = true
      AND DATE(start_time AT TIME ZONE 'UTC') BETWEEN p_start_date AND p_end_date
    GROUP BY DATE(start_time AT TIME ZONE 'UTC')
    ORDER BY session_date DESC;
END;
$$;

-- ============================================================================
-- GRANTS
-- ============================================================================
-- Grant execute permissions on functions to anon and authenticated

GRANT EXECUTE ON FUNCTION vipasana_authenticate_device(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION vipasana_get_user_by_api_key(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION vipasana_get_user_stats(UUID) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION vipasana_calculate_streak(UUID) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION vipasana_check_subscription_active(UUID) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION vipasana_get_sessions_by_date_range(UUID, DATE, DATE) TO anon, authenticated;

-- ============================================================================
-- COMMENTS
-- ============================================================================
-- Add comments for documentation

COMMENT ON TABLE vipasana_users IS 'User profiles identified by anonymized device ID for Vipasana app';
COMMENT ON TABLE vipasana_meditation_sessions IS 'Meditation session records for tracking and statistics';
COMMENT ON TABLE vipasana_user_settings IS 'User preferences and app settings synced across devices';
COMMENT ON TABLE vipasana_subscription_history IS 'Audit trail for all subscription-related events';
COMMENT ON TABLE vipasana_agreement_logs IS 'Legal compliance tracking for user agreement acceptances';
COMMENT ON TABLE vipasana_api_keys IS 'API keys for device-based authentication without Supabase Auth';

COMMENT ON FUNCTION vipasana_authenticate_device(TEXT) IS 'Authenticates device and returns/creates user with API key';
COMMENT ON FUNCTION vipasana_get_user_by_api_key(TEXT) IS 'Returns user ID from API key for subsequent requests';
COMMENT ON FUNCTION vipasana_get_user_stats(UUID) IS 'Returns comprehensive statistics for a user';
COMMENT ON FUNCTION vipasana_calculate_streak(UUID) IS 'Calculates current meditation streak in consecutive days';
COMMENT ON FUNCTION vipasana_check_subscription_active(UUID) IS 'Returns true if user has active premium subscription';
COMMENT ON FUNCTION vipasana_get_sessions_by_date_range(UUID, DATE, DATE) IS 'Returns aggregated session data for a date range';

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
