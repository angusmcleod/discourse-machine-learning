import { ajax } from 'discourse/lib/ajax';
import Run from '../models/run';

export default Discourse.Route.extend({
  model() {
    return Run.list();
  },

  setupController: function(controller, model) {
    controller.set('runs', model);
  },

  deactivate() {
    this.controllerFor('adminMl.runs').set('activeLabel', null);
  }
});
