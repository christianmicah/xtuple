select xt.add_column('apapply','apapply_target_curr_id', 'INTEGER', NULL, 'public');

select xt.add_constraint('apapply','apapply_target_curr_id_fkey', 'foreign key (apapply_target_curr_id) references curr_symbol(curr_id)', 'public');
