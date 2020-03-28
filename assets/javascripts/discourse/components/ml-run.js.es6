import { getOwner } from 'discourse-common/lib/get-owner';

export default Ember.Component.extend({
  tagName: 'tr',

  status: function() {
    return I18n.t(`ml.admin.run.status.${this.get('run.status')}`);
  }.property('run.status'),

  actions: {
    destroy(run) {
      run.destroy();
    },

    test(run) {
      run.test();
    },

    goToDataset(run) {
      getOwner(this).lookup('router:main').transitionTo('adminMl.datasets')
      .then(function(newRoute) {
        newRoute.controller.set('activeLabel', run.dataset_label);
      });
    }
  }
});
