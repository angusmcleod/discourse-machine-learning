import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';

const Model = Discourse.Model.extend({
  buildImage() {
    ajax("models/build-model", { type: 'POST', data: {
       model_label: this.get('label')
     }
    }).then(function (result, error) {
     if (error) { popupAjaxError(error); }
    });
  },

  removeImage() {
    ajax("models/remove-image", { type: 'POST', data: {
       model_label: this.get('label')
     }
   }).then(function (result, error) {
      console.log(result, error)
     if (error) { popupAjaxError(error); }
    });
  },

  setRun(runLabel) {
    ajax("models/set-run", { type: 'POST', data: {
       model_label: this.get('label'),
       run_label: runLabel
     }
    }).then(function (result, error) {
     if (error) { popupAjaxError(error); }
    });
  },

  setInput(inputLabel) {
    ajax("models/set-input", { type: 'POST', data: {
       model_label: this.get('label'),
       input_label: inputLabel
     }
    }).then(function (result, error) {
     if (error) { popupAjaxError(error); }
    });
  },

  train(datasetLabel) {
    ajax("runs/train", { type: 'POST', data: {
       model_label: this.get('label'),
       dataset_label: datasetLabel
     }
    }).then(function (result, error) {
     if (error) { popupAjaxError(error); }
    });
  },

  destroy() {
    return ajax("/admin/backups/" + this.get("filename"), { type: "DELETE" });
  }
});

Model.reopenClass({
  list() {
    return ajax('/admin/ml/models.json').then((result) => {
      let models = [];
      result.forEach((r) => {
        models.push(Model.create(r));
      });
      return models;
    })
  }
});

export default Model;
