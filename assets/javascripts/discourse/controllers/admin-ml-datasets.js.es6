import showModal from 'discourse/lib/show-modal';
import Dataset from '../models/dataset';

export default Ember.Controller.extend({
  datasets: Ember.A(),

  subscribeToDatasets: function() {
    let self = this;
    this.messageBus.subscribe('/admin/ml/datasets', function(response) {
      if (response.action === 'remove') {
        self.set('datasets', self.get('datasets').filter((set) =>
          set.label !== response.label
        ));
      }
    })
  }.on('init'),

  actions: {
    openDatasetUpload() {
      showModal('dataset-upload');
    }
  }
});
