export default Ember.Controller.extend({
  models: Ember.A(),

  subscribeToModelStatus: function() {
    const models = this.get('models');
    models.forEach((model) => {
      this.messageBus.subscribe(`/admin/ml/models/${model.label}/status`, function(data) {
        console.log(data)
        model.set('status', data.status);
      })
    })
  }.observes('models.[]')
});
