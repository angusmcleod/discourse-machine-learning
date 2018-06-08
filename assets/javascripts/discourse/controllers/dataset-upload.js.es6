import Model from '../models/model';

const REQUIRED_DATA_FILES = [ "train.txt", "test.txt" ];

export default Ember.Controller.extend({
  modelLabels: [],
  title: 'ml.admin.dataset.upload.title',
  dataFiles: Ember.A(),

  setup: function() {
    Model.list().then((models) => {
      let modelLabels = [];
      let value = 0;
      models.forEach((model) => {
        modelLabels.push({name: model.get('label'), value: value});
        value++;
      })
      this.set('modelLabels', modelLabels);
    })
  }.on('init'),

  uploadTarget: function() {
    return `datasets/${this.getModelLabel()}/${this.get('setLabel')}`
  }.property('setLabel'),

  getModelLabel: function() {
    const index = this.get('modelIndex');
    const models = this.get('modelLabels');
    let model = models.filter(function(m) { return m.value === +index; })[0];
    return model.name;
  },

  uploadTitle: function() {
    return I18n.t('ml.admin.dataset.upload.data')
  }.property(),

  hasFiles: Ember.computed.notEmpty('dataFiles'),

  actions: {
    dataUploaded(upload) {
      const dataFiles = this.get('dataFiles');
      let dataType = upload.url.split('/').slice(-1).pop()
      if (dataFiles.indexOf(dataType) === -1) {
        dataFiles.pushObject(dataType);
      }
    },

    completeUpload() {
      this.send('closeModal');
      window.location.reload();
    }
  }
});
