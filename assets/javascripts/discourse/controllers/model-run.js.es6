import { ajax } from 'discourse/lib/ajax';
import Run from '../models/run';

export default Ember.Controller.extend({
  runLabels: [],
  title: 'ml.admin.model.run.title',

  setup: function() {
    Run.list().then((runs) => {
      let runLabels = [];
      let value = 0;
      runs.forEach((r) => {
        runLabels.push({name: r.get('label'), value: value});
        value++;
      })
      this.set('runLabels', runLabels)
    });
  }.on('init'),

  getRunLabel: function() {
    let label = this.get('runLabels').filter((l) => {
      return l.value === +this.get('runIndex');
    })[0];
    return label.name;
  },

  actions: {
    selectRun() {
      this.get('model').setRun(this.getRunLabel());
      this.send('closeModal');
    }
  }
});
