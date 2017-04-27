DO $$
BEGIN
  IF NOT EXISTS(SELECT 1
                  FROM information_schema.columns
                 WHERE table_name  = 'cohead'
                   AND column_name = 'cohead_type') THEN
    RAISE NOTICE 'cohead_type has already been removed';

  ELSIF EXISTS(SELECT 1 FROM cohead
                WHERE cohead_type IS NOT NULL) THEN
    RAISE NOTICE 'cohead_type is populated and could not be removed';

  ELSE
    ALTER TABLE public.cohead DROP COLUMN IF EXISTS cohead_type;
    RAISE NOTICE 'cohead_type has been removed';
  END IF;

  RETURN;
END;
$$ language plpgsql;
