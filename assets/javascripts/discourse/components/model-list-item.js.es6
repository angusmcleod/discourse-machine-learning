import { ajax } from 'discourse/lib/ajax';

export default Ember.Component.extend({
  tagName: 'div',
  unbuilt: Ember.computed.not('built'),

  status: function() {
    return I18n.t(`ml.admin.models.statuses.${this.get('model.status')}`);
  }.property('model.status'),

  built: function() {
    return this.get('model.status') > 2
  }.property('model.status'),

  building: function() {
    return this.get('model.status') === 2
  }.property('model.status'),

  actions: {
    buildModelImage(model) {
      ajax("build-model-image", {
       type: 'POST',
       data: {
         label: model.label,
       }
      }).then(function (result, error) {
       if (error) {
         popupAjaxError(error);
       }
      });
    },

    removeModelImage(model) {
      ajax("remove-model-image", {
       type: 'POST',
       data: {
         label: model.label,
       }
      }).then(function (result, error) {
       if (error) {
         popupAjaxError(error);
       }
      });
    }
  }
});
