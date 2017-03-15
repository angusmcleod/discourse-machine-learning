import Run from '../models/run';

export default Ember.Controller.extend({
  runs: Ember.A(),
  activeLabel: null,

  visibleRuns: function() {
    return this.get('activeLabel') ?
           this.get('runs').filter((r) => r.label === this.get('activeLabel')):
           this.get('runs');
  }.property('runs', 'activeLabel'),

  subscribeToRunStatus: function() {
    let self = this;
    this.messageBus.subscribe(`/admin/ml/runs`, function(data) {
      console.log(data)

      if (data.placeholder) {
        self.get('runs').pushObject(Run.create(data));
        return
      }

      if (data.accuracy) {
        let run = self.get('runs').findBy('label', data.label)
        run.set('accuracy', data.accuracy);
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
  }.on('init'),

  actions: {
    clearFilter() {
      this.set('activeLabel', null)
    }
  }
});
