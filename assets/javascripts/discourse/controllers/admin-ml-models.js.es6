export default Ember.Controller.extend({
  models: Ember.A(),

  subscribeToModelStatus: function() {
    let self = this;
    this.messageBus.subscribe("/admin/ml/models", function(data) {
      console.log(data)

      if (data.status) {
        let model = self.get('models').findBy('label', data.label);
        model.set('status', data.status);
      }

      if (data.run_label) {
        let model = self.get('models').findBy('label', data.label);
        model.set('run_label', data.run_label);
      }
    })
  }.on('init')
});
