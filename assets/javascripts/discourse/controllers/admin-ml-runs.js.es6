import Run from '../models/run';

export default Ember.Controller.extend({
  runs: Ember.A(),

  subscribeToRunStatus: function() {
    let self = this;
    this.messageBus.subscribe(`/admin/ml/runs`, function(data) {
      console.log(data)

      if (data.placeholder) {
        self.get('runs').pushObject(Run.create(data));
        return
      }

      if (data.status) {
        let run = self.get('runs').findBy('label', data.label)
        run.set('status', data.status);
        return
      }

      if (data.dataset_label) {
        let run = self.get('runs').findBy('label', data.label)
        run.set('data_label', data.dataset_label);
        return
      }

      if (data.action === 'remove') {
        self.set('runs', self.get('runs').filter((run) =>
          run.label !== data.label
        ));
        return
      }

      if (data.new_run) {
        window.location.reload();
      }
    })
  }.on('init')
});
