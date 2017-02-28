import { ajax } from 'discourse/lib/ajax'

export default Ember.Controller.extend({
  models: [],

  subscribeToModelStatus: function() {
    const models = this.get('models');
    models.forEach((model) => {
      this.messageBus.subscribe(`/admin/ml/models/${model.label}/status`, function(data) {
        console.log(data)
        model.set('status', data.status);
      })
    })
  }.observes('models'),

  actions: {
    buildModelImage(model) {
      ajax("build-model-image", {
       type: 'POST',
       data: {
         label: model.label,
       }
      }).then(function (result, error) {
       if (error) {
         popupAjaxError(error);
       }
      });
    }
  }
});
