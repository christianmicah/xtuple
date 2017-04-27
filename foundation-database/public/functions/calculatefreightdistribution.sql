CREATE OR REPLACE FUNCTION calculatefreightdistribution(
    pVoheadid integer,
    pCostElement integer,
    pDistrType text,
    pFreight numeric,
    pUpdateCosts boolean DEFAULT FALSE)
  RETURNS SETOF freightdistr AS $$
-- Copyright (c) 1999-2016 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _total   RECORD;
  _item    RECORD;
  _row     freightdistr%ROWTYPE;
BEGIN

  SELECT SUM(voitem_qty) as qty, SUM((voitem_qty * poitem_unitprice)) as price, SUM(voitem_qty * (item_prodweight + item_packweight)) as wgt
  INTO _total
  FROM voitem
  JOIN poitem ON (voitem_poitem_id=poitem_id)
  JOIN itemsite ON (poitem_itemsite_id=itemsite_id)
  JOIN item ON (itemsite_item_id=item_id)
  WHERE voitem_vohead_id=pVoHeadid
    AND itemsite_costmethod IN ('A', 'S')
    AND itemsite_controlmethod <> 'N'
    AND item_type IN ('M', 'P');

-- Distribution checks
  IF (_total.qty IS NULL) THEN
    RAISE EXCEPTION 'Voucher Items not yet distributed [xtuple: calculateFreightDistribution, -1]';
  END IF;

  FOR _item IN
    SELECT vohead_curr_id, vohead_distdate,
           itemsite_id, itemsite_costmethod, item_id,
           CASE WHEN itemsite_costmethod = 'A' THEN 
                     costcat_asset_accnt_id
                ELSE costcat_freight_accnt_id END AS accnt_id,
           voitem_poitem_id AS poitem, 
           voitem_qty AS qty, 
           (voitem_qty * poitem_unitprice) as price, 
           voitem_qty * (item_prodweight + item_packweight) as wgt
    FROM voitem
    JOIN vohead ON (voitem_vohead_id=vohead_id)
    JOIN poitem ON (voitem_poitem_id=poitem_id)
    JOIN itemsite ON (poitem_itemsite_id=itemsite_id)
    JOIN item ON (itemsite_item_id=item_id)
    JOIN costcat ON (itemsite_costcat_id=costcat_id)
    WHERE voitem_vohead_id=pVoHeadid 
      AND itemsite_costmethod IN ('A', 'S')
      AND itemsite_controlmethod <> 'N'
      AND item_type IN ('M', 'P')
  LOOP

    _row.freightdistr_vohead_id := pVoheadid;
    _row.freightdistr_poitem_id := _item.poitem;
    _row.freightdistr_accnt_id := _item.accnt_id;
      
    CASE pDistrType
      WHEN 'Q' THEN
        IF (_total.qty = 0) THEN
          RAISE EXCEPTION 'Voucher totals equal zero [xtuple: calculateFreightDistribution, -2]';
        END IF;  
        _row.freightdistr_amount := (_item.qty / _total.qty) * pFreight;
      WHEN 'V' THEN
        IF (_total.price = 0) THEN
          RAISE EXCEPTION 'Voucher totals equal zero [xtuple: calculateFreightDistribution, -2]';
        END IF;      
        _row.freightdistr_amount := (_item.price / _total.price) * pFreight;
      WHEN 'W' THEN
        IF (_total.wgt = 0) THEN
          RAISE EXCEPTION 'Voucher totals equal zero [xtuple: calculateFreightDistribution, -2]';
        END IF;      
        _row.freightdistr_amount := (_item.wgt / _total.wgt) * pFreight;
    END CASE;

    IF (pUpdateCosts) THEN
      IF (_item.itemsite_costmethod = 'A') THEN
        -- Update Item Site Average cost with freight amount
        UPDATE itemsite 
        SET itemsite_value = itemsite_value + currToBase(_item.vohead_curr_id, _row.freightdistr_amount,
			      _item.vohead_distdate)
	WHERE itemsite_id = _item.itemsite_id;
      END IF;
      -- Update Actual Costs for all items
        UPDATE itemcost
          SET itemcost_actcost=itemcost_actcost + (currtocurr(_item.vohead_curr_id, itemcost_curr_id,
                   _row.freightdistr_amount, _item.vohead_distdate) / _item.qty)
          WHERE itemcost_item_id = _item.item_id
          AND   itemcost_costelem_id = pCostElement
          AND NOT itemcost_lowlevel;
        INSERT INTO itemcost (itemcost_item_id, itemcost_costelem_id, itemcost_lowlevel,
                              itemcost_posted, itemcost_actcost, itemcost_updated,
                              itemcost_curr_id)
          SELECT _item.item_id, pCostElement, false,
                 _item.vohead_distdate, (_row.freightdistr_amount / _item.qty), _item.vohead_distdate,
                 _item.vohead_curr_id
          WHERE NOT EXISTS (SELECT 1 FROM itemcost 
                            WHERE itemcost_item_id = _item.item_id
                            AND itemcost_costelem_id = pCostElement
                            AND itemcost_lowlevel = false);       
    END IF;

    RETURN NEXT _row;

  END LOOP;  

END;
$$ LANGUAGE plpgsql;

