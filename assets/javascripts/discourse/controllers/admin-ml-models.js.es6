import { ajax } from 'discourse/lib/ajax'

export default Ember.Controller.extend({

  subscribeToModelStatus: function() {
    const models = this.get('models')
    models.forEach((model) => {
      this.messageBus.subscribe(`/admin/ml/${model.name}/status`, function(data) {
        model.set('status', data.status)
      })
    })
  }.observes('models'),

  actions: {
    buildImage(model) {
     ajax("admin/ml/build-image", {
       type: 'POST',
       data: {
         name: model.name,
       }
     }).then(function (result, error) {
       if (error) {
         popupAjaxError(error);
       }
     });
    }
  }
});
