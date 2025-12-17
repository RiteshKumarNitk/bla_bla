-- Function to calculate user ratings stats
CREATE OR REPLACE FUNCTION get_user_ratings_stats(user_id_input uuid)
RETURNS json
LANGUAGE plpgsql
AS $$
DECLARE
    result json;
BEGIN
    SELECT json_build_object(
        'average_rating', COALESCE(AVG(rating), 0),
        'total_reviews', COUNT(*)
    )
    INTO result
    FROM reviews
    WHERE reviewee_id = user_id_input;

    RETURN result;
END;
$$;
