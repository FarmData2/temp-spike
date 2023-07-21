<template>
  <div>
    The FarmData2 School module appears in the development environment. It provides a working space
    for the FD2School Onboarding activities. Each of the activities create a new entry point in this
    menu as a way to learn about developing FarmData2 features.
  </div>
  <div data-cy="page-loaded" v-show="false">{{ pageDoneLoading }}</div>
</template>

<script>
export default {
  data() {
    return {
      createdCount: 0,
    }
  },
  computed: {
    pageDoneLoading() {
      return this.createdCount == 1
    },
  },
  created() {
    this.createdCount++
  },
}
</script>
