import { ajax } from 'discourse/lib/ajax';
import Model from '../models/model';

export default Discourse.Route.extend({
  model() {
    return Model.list();
  },

  setupController: function(controller, model) {
    controller.set('models', model);
  }
});
