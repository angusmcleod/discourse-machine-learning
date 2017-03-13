import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';

const Dataset = Discourse.Model.extend({
  destroy() {
    return ajax(`/admin/ml/datasets/${this.get('model_label')}/${this.get('label')}`, { type: "DELETE" });
  }
});

Dataset.reopenClass({
  list() {
    return ajax('/admin/ml/datasets.json').then((result) => {
      let datasets = [];
      result.forEach((dataset) => {
        datasets.push(Dataset.create(dataset));
      });
      return datasets;
    })
  }
});

export default Dataset;
