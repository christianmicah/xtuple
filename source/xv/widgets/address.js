/*jshint node:true, indent:2, curly:true eqeqeq:true, immed:true, latedef:true, newcap:true, noarg:true,
regexp:true, undef:true, trailing:true, white:true */
/*global XT:true, XV:true, XM:true, Backbone:true, enyo:true, _:true */

(function () {

  enyo.kind({
    name: "XV.AddressWidget",
    kind: "FittableRows",
    classes: "xv-addresswidget",
    published: {
      attr: null,
      value: null
    },
    events: {
      onValueChange: ""
    },
    handlers: {
      onkeyup: "keyUp"
    },
    components: [
      {kind: "enyo.TextArea", name: "viewer", showing: true, fit: true,
        tag: 'textarea rows="5" readonly=readonly',
        classes: "xv-addresswidget-viewer", placeholder: "_none".loc()},
      {kind: "onyx.Button", content: "_edit".loc(), ontap: "edit", onkeyup: "buttonKeyUp"},
      {kind: "onyx.Popup", name: "editor", onHide: "editorHidden",
        classes: "xv-addresswidget-editor", modal: true, floating: true,
        centered: true, scrim: true, components: [
        {content: "_editAddress".loc(),
          classes: "xv-addresswidget-editor-header"},
        {kind: "onyx.InputDecorator", fit: true,
          classes: "xv-addresswidget-input-decorator",
          components: [
          {kind: "onyx.Input", name: "line1",
            placeholder: "_street".loc(), classes: "xv-addresswidget-input",
            onchange: "inputChanged"}
        ]},
        {kind: "onyx.InputDecorator", fit: true,
          classes: "xv-addresswidget-input-decorator",
          components: [
          {kind: "onyx.Input", name: "line2",
            classes: "xv-addresswidget-input", onchange: "inputChanged"}
        ]},
        {kind: "onyx.InputDecorator", fit: true,
          classes: "xv-addresswidget-input-decorator",
          components: [
          {kind: "onyx.Input", name: "line3",
            classes: "xv-addresswidget-input", onchange: "inputChanged"}
        ]},
        {kind: "onyx.InputDecorator", fit: true,
          classes: "xv-addresswidget-input-decorator",
          components: [
          {kind: "onyx.Input", name: "city", placeholder: "_city".loc(),
            classes: "xv-addresswidget-input", onchange: "inputChanged"}
        ]},
        {kind: "onyx.InputDecorator", fit: true,
          classes: "xv-addresswidget-combobox-decorator",
          components: [
          {kind: "XV.StateCombobox", name: "state", placeholder: "_state".loc(),
            onValueChange: "inputChanged"}
        ]},
        {kind: "onyx.InputDecorator", fit: true,
          classes: "xv-addresswidget-input-decorator",
          components: [
          {kind: "onyx.Input", name: "postalCode",
            classes: "xv-addresswidget-input", placeholder: "_postalCode".loc(), onchange: "inputChanged"}
        ]},
        {kind: "onyx.InputDecorator", fit: true,
          classes: "xv-addresswidget-combobox-decorator",
          components: [
          {kind: "XV.CountryCombobox", name: "country",
            onValueChange: "countryChanged",
            placeholder: "_country".loc()}
        ]},
        {tag: "br"},
        {kind: "onyx.Button", content: "_done".loc(), ontap: "done",
          classes: "onyx-blue"}
      ]}
    ],
    buttonKeyUp: function (inSender, inEvent) {
      // Return or space bar activates button
      if (inEvent.keyCode === 13 ||
         (inEvent.keyCode === 32)) {
        this.edit();
      }
      return true;
    },
    countryChanged: function (inSender, inEvent) {
      var country = this.$.country.getValue();
      this.inputChanged(inSender, inEvent);
      this.$.state.setCountry(country);
      return true;
    },
    done: function () {
      this._popupDone = true;
      this.$.editor.hide();
      this.$.viewer.focus();
    },
    inputChanged: function (inSender, inEvent) {
      var value = this.getValue(),
        attr = inEvent.originator.name;
      value.set(attr, this.$[attr].getValue());
      this.setValue(value);
      this.valueChanged();
      inEvent = {
        originator: this,
        value: value
      };
      this.doValueChange(inEvent);
      return true;
    },
    keyUp: function (inSender, inEvent) {
      // Return
      if (inEvent.keyCode === 13) {
        this.done();
      }
    },
    edit: function (inSender, inEvent) {
      var value = this.getValue();
      if (!value) {
        value = new XM.AddressInfo(null, {isNew: true});
        this.setValue(value);
      }
      if (!this.$.editor.showing) {
        this.$.editor.show();
        this.$.line1.focus();
        this._popupDone = false;
      }
    },
    editorHidden: function () {
      if (!this._popupDone) {
        this.edit();
      }
    },
    setValue: function (value, options) {
      var inEvent,
        oldId = this.value ? this.value.id : null,
        newId = value ? value.id : null;
      options = options || {};
      if (newId === oldId) { return; }
      this.value = value;
      this.valueChanged();
      if (!options.silent) {
        inEvent = {
          originator: this,
          value: value
        };
        this.doValueChange(inEvent);
      }
    },
    pickerTapped: function (inSender, inEvent) {
      if (inEvent.originator.name === "iconButton") {
        this.receiveFocus();
      }
    },
    valueChanged: function () {
      var value = this.getValue(),
        line1 = value.get('line1') || "",
        line2 = value.get('line2') || "",
        line3 = value.get('line3') || "",
        city = value.get('city') || "",
        state = value.get('state') || "",
        postalCode = value.get('postalCode') || "",
        country = value.get('country') || "",
        fmt = XM.Address.format(value);
      this.$.line1.setValue(line1);
      this.$.line2.setValue(line2);
      this.$.line3.setValue(line3);
      this.$.city.setValue(city);
      this.$.state.setValue(state);
      this.$.postalCode.setValue(postalCode);
      this.$.country.setValue(country);
      this.$.viewer.setValue(fmt);
    }

  });
}());
