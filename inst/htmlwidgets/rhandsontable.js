HTMLWidgets.widget({
  name: 'rhandsontable',
  type: 'output',
  params: null,
  initialize: function(el, width, height) {
    return {};
  },

  renderValue: function(el, x, instance) {
    if (x.data.length > 0 && x.data[0].constructor === Array) {
      x.data = x.data;
    } else {
      x.data = toArray(x.data.map(function(d) {
        return x.rColnames.map(function(ky) {
          return d[ky];
        });
      }));
    }
    if (x.overflow) {
      $("#" + el.id).css('overflow', x.overflow);
    }
    if (x.rowHeaderWidth) {
      $("#" + el.id).css('col.rowHeader', x.rowHeaderWidth + 'px');
    }

    x.outsideClickDeselects = false;

    this.params = x;

    if (instance.hot) {
      instance.hot.params = x;
      instance.hot.updateSettings(x);
    } else {
      instance.hot = new Handsontable(el, x);
      this.afterChangeCallback(x);
      this.afterCellMetaCallback(x);
      this.beforeCutCallback(x);
      if (x.selectCallback) {
        this.afterSelectCallback(x);
      }
      instance.hot.params = x;
      instance.hot.updateSettings(x);
    }
  },

  resize: function(el, width, height, instance) {
      //console.log("rhandsontable is resized");
      //console.log("width");
      //console.log(width);
      //console.log("height");
      //console.log(height);
  },

  afterRender: function(x) {
    x.afterRender = function(isForced) {
      var plugin = this.getPlugin('autoColumnSize');
      if (plugin.isEnabled() && this.params) {
        var wdths = plugin.widths;
        for(var i = 0, colCount = this.countCols(); i < colCount ; i++) {
          if (this.params.columns && this.params.columns[i].renderer.name != "customRenderer") {
            plugin.calculateColumnsWidth(i, 300, true);
          }
        }
      }
    };
  },

  beforeCutCallback: function(x) {
    x.beforeCut = function(data, coords) {
      // Cut is disabled
      return false;
    };
  },

  afterChangeCallback: function(x) {
    x.afterChange = function(changes, source) {
      if (HTMLWidgets.shinyMode) {

        if (changes && (changes[0][2] !== null || changes[0][3] !== null)) {
          if (this.sortIndex && this.sortIndex.length !== 0) {
            c = [this.sortIndex[changes[0][0]][0], changes[0].slice(1, 1 + 3)];
          } else {
            c = changes;
          }

          // Can only be 1 row at a time
          if (source == "edit") {
            var obj = {
              changerow: changes[0][0] +1,
              changecol: changes[0][1] +1,
              oldval: changes[0][2],
              newval: changes[0][3]
            };
            // Wenn sich der Wert verändert hat, set Shiny Value ("tableID_edit")
            if (obj.oldval !== obj.newval) {
              Shiny.setInputValue(this.rootElement.id+"_edit", obj, {priority: "event"});
            }
          }
          // Can be multi-row edit
          if (source == "Autofill.fill") {
            var obj1 = flattenArray(changes);
            Shiny.setInputValue(this.rootElement.id+"_fill", obj1, {priority: "event"});
          }
          // Can be multi-row edit
          if (source == "UndoRedo.redo") {
            return false;
            //var obj = flattenArray(changes);
            //Shiny.setInputValue(this.rootElement.id+"_redo", obj, {priority: "event"});
          }
          // Can be multi-row edit
          if (source == "UndoRedo.undo") {
            return false;
            //var obj = flattenArray(changes);
            //Shiny.setInputValue(this.rootElement.id+"_undo", obj, {priority: "event"});
          }


          /*Shiny.onInputChange(this.rootElement.id, {
            data: this.getData(),
            changes: { event: "afterChange", changes: c, source: source },
            params: this.params
          });*/
        } else if (source == "loadData" && this.params) {
          Shiny.onInputChange(this.rootElement.id, {
            data: this.getData(),
            changes: { event: "afterChange", changes: null },
            params: this.params
          });
        }
      }
    };

    // Used with editable tables. Is emitted after something is pasted in the table
    x.afterPaste = function(data, coords) {
      var obj = {
        startrow: coords[0].startRow+1,
        endrow: coords[0].endRow+1,
        startcol: coords[0].startCol+1,
        endcol: coords[0].endCol+1,
        vals: data
      };
      Shiny.setInputValue(this.rootElement.id+"_pasted", obj, {priority: "event"});
    };
  },
  afterCellMetaCallback: function(x) {
    x.afterSetCellMeta = function(r, c, key, val) {
      if (HTMLWidgets.shinyMode && key === "comment") {
        Shiny.onInputChange(this.rootElement.id + "_comment", {
          data: this.getData(),
          comment: { r: r + 1, c: c + 1, key: key, val: val},
          params: this.params
        });
      }
    };
  },
  afterSelectCallback: function(x) {
    x.afterSelectionEnd = function(r, c, r2, c2) {
      // Get selected rows (flatten array and get even element and add 1);
      var selrows = this.getSelected();
      Shiny.setInputValue(this.rootElement.id+"_selected", selrows);
    };

    //x.afterDeselect = function(e) {
    //  Shiny.setInputValue(this.rootElement.id+"_selected", null);
    //};
  },
});



// HELPER FUNCTIONS
// https://stackoverflow.com/questions/22477612/converting-array-of-objects-into-array-of-arrays
function toArray(input) {
  var result = input.map(function(obj) {
    return Object.keys(obj).map(function(key) {
      return obj[key];
    });
  });
  return result;
}

function getEvenArray(array) {
  ar = [];
  var arflat = array.flat();
  for(var i = 0; i < arflat.length; i += 2) {  // take every second element
  	ar.push(arflat[i] + 1);
  }
  return(ar);
}

function flattenArray(changes) {
  var arr = {changerow:[], changecol:[], oldval:[], newval:[]};
  for (var i=0; i < changes.length; i++) {
  	arr.changerow.push(changes[i][0]+1);
  	arr.changecol.push(changes[i][1]+1);
  	arr.oldval.push(changes[i][2]);
  	arr.newval.push(changes[i][3]);
  }
  return arr;
}

function csvString(instance, sep, dec) {
  var headers = instance.getColHeader();
  var csv = headers.join(sep) + "\n";
  for (var i = 0; i < instance.countRows(); i++) {
      var row = [];
      for (var h in headers) {
          var col = instance.propToCol(h);
          var value = instance.getDataAtRowProp(i, col);
          if ( !isNaN(value) ) {
            value = value.toString().replace(".", dec);
          }
          row.push(value);
      }
      csv += row.join(sep);
      csv += "\n";
  }
  return csv;
}

function customRenderer(instance, TD, row, col, prop, value, cellProperties) {
    if (['date', 'handsontable', 'dropdown'].indexOf(cellProperties.type) > -1) {
      type = 'autocomplete';
    } else {
      type = cellProperties.type;
    }
    Handsontable.renderers.getRenderer(type)(instance, TD, row, col, prop, value, cellProperties);
}

function strip_tags(input, allowed) {
  var tags = /<\/?([a-z][a-z0-9]*)\b[^>]*>/gi,
    commentsAndPhpTags = /<!--[\s\S]*?-->|<\?(?:php)?[\s\S]*?\?>/gi;
  allowed = (((allowed || "") + "").toLowerCase().match(/<[a-z][a-z0-9]*>/g) || []).join('');
  return input.replace(commentsAndPhpTags, '').replace(tags, function ($0, $1) {
    return allowed.indexOf('<' + $1.toLowerCase() + '>') > -1 ? $0 : '';
  });
}

function safeHtmlRenderer(instance, td, row, col, prop, value, cellProperties) {
  var escaped = Handsontable.helper.stringify(value);
  if (instance.getSettings().allowedTags) {
    tags = instance.getSettings().allowedTags;
  } else {
    tags = '<em><b><strong><a><big>';
  }
  escaped = strip_tags(escaped, tags);
  td.innerHTML = escaped;
  return td;
}
