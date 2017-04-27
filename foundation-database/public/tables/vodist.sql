select xt.add_column('vodist','vodist_taxtype_id', 'INTEGER', NULL, 'public');
select xt.add_column('vodist','vodist_freight_vohead_id', 'INTEGER', NULL, 'public');
select xt.add_column('vodist','vodist_freight_dist_method', 'TEXT', NULL, 'public');

select xt.add_constraint('vodist','vodist_taxtype_id_fkey', 'foreign key (vodist_taxtype_id) references taxtype(taxtype_id)', 'public');
select xt.add_constraint('vodist','vodist_freight_vohead_id_fkey', 'foreign key (vodist_freight_vohead_id) references vohead(vohead_id)', 'public');
select xt.add_constraint('vodist','vodist_freight_dist_method_check', 'CHECK (vodist_freight_dist_method IN (''Q'', ''V'', ''W''))', 'public');

COMMENT ON COLUMN public.vodist.vodist_freight_vohead_id
  IS 'The original Voucher to determine the items freight will be distributed to';
COMMENT ON COLUMN public.vodist.vodist_freight_dist_method
  IS 'The Freight distribution method';

