DROP FUNCTION IF EXISTS xt.createwf(text, anyelement);

CREATE OR REPLACE FUNCTION xt.createwf(tg_table_name text,
                                       tg_table_row  anyelement)
  RETURNS record AS $$
/* Copyright (c) 1999-2016 by OpenMFG LLC, d/b/a xTuple.
   See www.xtuple.com/CPAL for the full text of the software license. */
DECLARE
  _wftypecode     TEXT;
  _source_model   TEXT;
  _workflow_class TEXT;
  _item_uuid      UUID;
  _parent_id      INTEGER;
  _order_id       INTEGER;
  _poStatus       TEXT;

BEGIN
  IF fetchmetricbool('TriggerWorkflow') THEN

    IF tg_table_name = 'cohead' THEN
      _wftypecode := 'SO';
      _workflow_class := 'XM.SalesOrderWorkflow';
      _item_uuid := tg_table_row.obj_uuid;
      _parent_id := tg_table_row.cohead_saletype_id;
      _order_id  := tg_table_row.cohead_id;

      -- Copy Sale Type chars to Sales Order.
      PERFORM xt.copychars('ST', _parent_id, 'S', _order_id);

      -- Currently `xt.saletypeext` is webenabled database only.
      -- TODO: Add column to `public.saletype` table.
      IF EXISTS(SELECT 1
                  FROM pg_class c
                  JOIN pg_namespace n ON n.oid = c.relnamespace
                 WHERE n.nspname = 'xt'
                   AND c.relname = 'saletypeext'
                   AND c.relkind = 'r' -- table
               ) THEN
        UPDATE cohead
           SET cohead_holdtype = saletypeext_default_hold_type
          FROM xt.saletypeext
         WHERE cohead_id = _order_id
           AND saletypeext_id = _parent_id
           AND saletypeext_default_hold_type IS NOT NULL;
      END IF;

    ELSIF tg_table_name = 'prj' THEN
      _wftypecode := 'PRJ';
      _workflow_class := 'XM.ProjectWorkflow';
      _item_uuid := tg_table_row.obj_uuid;
      _parent_id := tg_table_row.prj_prjtype_id;
      _order_id  := tg_table_row.prj_id;

    ELSIF tg_table_name = 'pohead' THEN
      _wftypecode := 'PO';
      _workflow_class := 'XM.PurchaseOrderWorkflow';
      SELECT poheadext_potype_id, pohead_id, pohead.obj_uuid, pohead_status
        INTO _parent_id, _order_id, _item_uuid, _poStatus
        FROM pohead JOIN xt.poheadext ON poheadext_id = pohead_id
       WHERE pohead_id = tg_table_row.pohead_id;
      IF _parent_id IS NULL THEN
        RAISE DEBUG 'Cannot find parentId needed to generate workflow [%, %]',
                        tg_table_name, tg_table_row.pohead_id;
      END IF;
      IF _poStatus <> 'O' THEN
        RETURN tg_table_row;
      END IF;

    ELSIF tg_table_name = 'poheadext' THEN
      _wftypecode := 'PO';
      _workflow_class := 'XM.PurchaseOrderWorkflow';
      SELECT poheadext_potype_id, pohead_id, pohead.obj_uuid, pohead_status
        INTO _parent_id, _order_id, _item_uuid, _poStatus
        FROM pohead JOIN xt.poheadext ON poheadext_id = pohead_id
       WHERE pohead_id = tg_table_row.poheadext_id;
      IF _parent_id IS NULL THEN
        RAISE DEBUG 'Cannot find parentId needed to generate workflow [%, %]',
                        tg_table_name, tg_table_row.poheadext_id;
      END IF;
      IF _poStatus <> 'O' THEN
        RETURN tg_table_row;
      END IF;

    ELSIF tg_table_name = 'tohead' THEN
      _wftypecode := 'TO';
      _workflow_class := 'XM.TransferOrderWorkflow';
      _item_uuid := tg_table_row.obj_uuid;
      SELECT warehous_sitetype_id INTO _parent_id
        FROM whsinfo
       WHERE warehous_id = tg_table_row.tohead_src_warehous_id;
      IF _parent_id IS NULL THEN
        RAISE DEBUG 'Cannot find parentId needed to generate workflow [%, %]',
                        tg_table_name, tg_table_row.tohead_src_warehous_id;
      END IF;
      _order_id := tg_table_row.tohead_id;

    ELSIF tg_table_name = 'wo' THEN
      _wftypecode := 'WO';
      _workflow_class := 'XM.WorkOrderWorkflow';
      _item_uuid := tg_table_row.obj_uuid;
      SELECT itemsite_plancode_id INTO _parent_id
        FROM itemsite
       WHERE itemsite_id = tg_table_row.wo_itemsite_id;
      IF _parent_id IS NULL THEN
        RAISE DEBUG 'Cannot find parentId needed to generate workflow [%, %]',
                        tg_table_name, tg_table_row.wo_itemsite_id;
      END IF;
      _order_id := tg_table_row.wo_id;
      IF (SELECT wo_status FROM wo WHERE wo_id = _order_id) <> 'R' THEN
        RETURN tg_table_row;
      END IF;

    ELSE
      RAISE EXCEPTION 'Improper table supplied to createwf function [xtuple: createwf, -2, %]', tg_table_name;
    END IF;

    SELECT wftype_src_tblname INTO _source_model
      FROM xt.wftype
     WHERE wftype_code = _wftypecode;
    IF _source_model IS NOT NULL THEN
      PERFORM xt.workflow_inheritsource('xt.' || _source_model, _workflow_class,
                                        _item_uuid, _parent_id, _order_id);
    ELSE
      RAISE WARNING 'Cannot find source table needed to generate workflow for type % (%)',
                    _wftypecode, tg_table_name;
    END IF;

  END IF;

  RETURN tg_table_row;
END;

$$ LANGUAGE plpgsql;
ALTER FUNCTION xt.createwf(text, anyelement) OWNER TO admin;
