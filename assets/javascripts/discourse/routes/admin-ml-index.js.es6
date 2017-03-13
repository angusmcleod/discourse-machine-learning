export default Discourse.Route.extend({
  redirect() {
    this.transitionTo('adminMl.models');
  }
});
