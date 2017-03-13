import { ajax } from 'discourse/lib/ajax';
import Dataset from '../models/dataset';

export default Discourse.Route.extend({
  model() {
    return Dataset.list();
  },

  setupController: function(controller, model) {
    controller.set('datasets', model);
  }
});
