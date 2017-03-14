import { ajax } from 'discourse/lib/ajax';
import showModal from 'discourse/lib/show-modal';
import { getOwner } from 'discourse-common/lib/get-owner';

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

  runLink: function() {
    return model.run_label
  },

  actions: {
    buildImage(model) {
      model.buildImage();
    },

    removeImage(model) {
      model.removeImage();
    },

    openTrainModel(model) {
      showModal('model-train', { model: model });
    },

    goToRun(model) {
      getOwner(this).lookup('router:main').transitionTo('adminMl.runs')
      .then(function(newRoute) {
        newRoute.controller.set('activeLabel', model.run_label);
      });
    }
  }
});
