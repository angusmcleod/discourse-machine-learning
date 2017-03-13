import { ajax } from 'discourse/lib/ajax';
import showModal from 'discourse/lib/show-modal';

export default Ember.Component.extend({
  tagName: 'div',
  classNames: ['table-item'],
  unbuilt: Ember.computed.not('built'),
  building: Ember.computed.equal('model.status', 2),
  built: Ember.computed.gt('model.status', 2),

  typeLabel: function() {
    return I18n.t(`ml.admin.model.type.${this.get('model.type')}`);
  }.property('model.status'),

  statusLabel: function() {
    return I18n.t(`ml.admin.model.status.${this.get('model.status')}`);
  }.property('model.status'),

  actions: {
    buildImage(model) {
      model.buildImage();
    },

    removeImage(model) {
      model.removeImage();
    },

    openTrainModel(model) {
      showModal('model-train', { model: model });
    }
  }
});
