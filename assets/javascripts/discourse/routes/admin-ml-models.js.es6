import { ajax } from 'discourse/lib/ajax'

export default Discourse.Route.extend({
  setupController: function(controller) {
    ajax('/admin/ml/models.json').then((response) => {
      controller.set('models', response)
    })
  }
});
