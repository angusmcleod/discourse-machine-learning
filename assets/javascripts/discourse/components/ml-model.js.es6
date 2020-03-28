import showModal from 'discourse/lib/show-modal';
import { getOwner } from 'discourse-common/lib/get-owner';

export default Ember.Component.extend({
  tagName: 'tr',

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
    openTrainModel(model) {
      showModal('model-train', { model: model });
    },

    openSelectRun(model) {
      showModal('model-run', { model: model });
    },

    goToRun(model) {
      getOwner(this).lookup('router:main').transitionTo('adminMl.runs')
      .then(function(newRoute) {
        newRoute.controller.set('activeLabel', model.run_label);
      });
    }
  }
});
