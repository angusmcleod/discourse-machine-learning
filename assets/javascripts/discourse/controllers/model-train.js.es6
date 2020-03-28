import Dataset from '../models/dataset';
import { empty } from "@ember/object/computed";

export default Ember.Controller.extend({
  datasetLabels: [],
  title: 'ml.admin.model.train.title',
  noDatasetIndex: empty('datasetIndex'),

  setup: function() {
    Dataset.list().then((datasets) => {
      let datasetLabels = [];
      let value = 0;
      datasets.forEach((set) => {
        datasetLabels.push({name: set.get('label'), value});
        value++;
      })
      this.set('datasetLabels', datasetLabels)
    });
  }.on('init'),

  getDatasetLabel: function() {
    let label = this.get('datasetLabels').filter((l) => {
      return l.value === +this.get('datasetIndex');
    })[0];
    return label.name;
  },

  actions: {
    startTraining(upload) {
      this.get('model').train(this.getDatasetLabel());
      this.send('closeModal');
      DiscourseURL.routeTo('/admin/ml/runs');
    }
  }
});
