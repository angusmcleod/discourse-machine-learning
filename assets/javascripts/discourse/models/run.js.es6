import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';

const Run = Discourse.Model.extend({
  destroy() {
    return ajax(`/admin/ml/runs/${this.get('model_label')}/${this.get('label')}`, { type: "DELETE" });
  },

  test() {
    ajax("runs/eval", { type: 'POST', data: {
       label: this.get('label'),
       test_run: true
     }
    }).then(function (result, error) {
     if (error) { popupAjaxError(error); }
    });
  }
});

Run.reopenClass({
  list() {
    return ajax('/admin/ml/runs.json').then((result) => {
      let runs = [];
      result.forEach((r) => {
        runs.push(Run.create(r));
      });
      return runs;
    })
  }
});

export default Run;
