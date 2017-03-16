import { ajax } from 'discourse/lib/ajax';
import Input from '../models/input';

export default Ember.Controller.extend({
  inputLabels: [],
  title: 'ml.admin.model.input.title',

  setup: function() {
    Input.list().then((inputs) => {
      let inputLabels = [];
      let value = 0;
      inputs.forEach((i) => {
        inputLabels.push({name: i.get('label'), value: value});
        value++;
      })
      this.set('inputLabels', inputLabels)
    });
  }.on('init'),

  getInputLabel: function() {
    let label = this.get('inputLabels').filter((l) => {
      return l.value === +this.get('inputIndex');
    })[0];
    return label.name;
  },

  actions: {
    selectInput() {
      this.get('model').setInput(this.getInputLabel());
      this.send('closeModal');
    }
  }
});
