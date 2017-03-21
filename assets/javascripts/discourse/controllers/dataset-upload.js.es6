import Model from '../models/model';

const REQUIRED_DATA_FILES = [ "train.txt", "test.txt" ];

export default Ember.Controller.extend({
  modelLabels: [],
  title: 'ml.admin.dataset.upload.title',
  hasDataFile: Ember.A(),

  setup: function() {
    Model.list().then((models) => {
      let modelLabels = [];
      let value = 0;
      models.forEach((model) => {
        modelLabels.push({name: model.get('label'), value: value});
        value++;
      })
      this.set('modelLabels', modelLabels)
      this.set('dataLabel', + new Date())
    })
  }.on('init'),

  trainUploadTarget: function() {
    return this.getUploadTarget() + "/train";
  }.property(),

  testUploadTarget: function() {
    return this.getUploadTarget() + "/test";
  }.property(),

  getUploadTarget: function() {
    return `datasets/${this.getModelLabel()}/${this.get('dataLabel')}`
  },

  getModelLabel: function() {
    const index = this.get('modelIndex');
    const models = this.get('modelLabels');
    let model = models.filter(function(m) { return m.value === +index; })[0];
    return model.name;
  },

  trainUploadTitle: function() {
    return I18n.t('ml.admin.dataset.upload.data', {dataType: 'Train'})
  }.property(),

  testUploadTitle: function() {
    return I18n.t('ml.admin.dataset.upload.data', {dataType: 'Test'})
  }.property(),

  hasRequiredDataFiles: function() {
    return _.isEqual(this.get('hasDataFile'), REQUIRED_DATA_FILES)
  }.property('hasDataFile.[]'),

  actions: {
    dataUploaded(upload) {
      const hasDataFile = this.get('hasDataFile');
      let dataType = upload.url.split('/').slice(-1).pop()
      if (hasDataFile.indexOf(dataType) === -1) {
        hasDataFile.pushObject(dataType);
      }
    },

    completeUpload() {
      this.send('closeModal');
      window.location.reload();
    }
  }
});
