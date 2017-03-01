import { ajax } from 'discourse/lib/ajax'

export default Discourse.Route.extend({
  setupController: function(controller) {
    ajax('/admin/ml/models.json').then((response) => {
      const models = controller.get('models');
      response.forEach((model) => {
        models.pushObject(Ember.Object.create(model));
      })
    })
  }
});
