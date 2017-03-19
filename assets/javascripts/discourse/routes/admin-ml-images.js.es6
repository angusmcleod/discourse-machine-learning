import { ajax } from 'discourse/lib/ajax';
import Image from '../models/image';

export default Discourse.Route.extend({
  model() {
    return Image.list();
  },

  setupController: function(controller, model) {
    controller.set('images', model);
  },

  deactivate() {
    this.controllerFor('adminMl.images').set('activeLabel', null);
  }
});
