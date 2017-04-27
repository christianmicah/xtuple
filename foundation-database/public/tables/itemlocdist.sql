select xt.add_column('itemlocdist', 'itemlocdist_child_series', 'INTEGER', NULL, 'public');
select xt.add_column('itemlocdist', 'itemlocdist_transtype', 'TEXT', NULL, 'public');

COMMENT ON COLUMN public.itemlocdist.itemlocdist_order_id
  IS 'This is actually orderitem_id';
