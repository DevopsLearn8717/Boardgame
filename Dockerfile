FROM adoptopenjdk/openjdk11

EXPOSE 8080
 
ENV APP_HOME /usr/src/app

ARG artifact=target/*.jar

COPY ${artifact} $APP_HOME/app.jar

WORKDIR $APP_HOME

CMD ["java", "-jar", "app.jar"]
