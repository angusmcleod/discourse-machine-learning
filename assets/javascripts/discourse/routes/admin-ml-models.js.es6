import { ajax } from 'discourse/lib/ajax'

export default Discourse.Route.extend({
  setupController: function(controller) {
    ajax('/admin/ml/models.json').then((response) => {
      console.log(respose)
      controller.set('models', response.models)
    })
  }
});
